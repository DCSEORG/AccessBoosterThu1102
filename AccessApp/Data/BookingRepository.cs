using AccessApp.Models;
using Microsoft.Data.Sqlite;

namespace AccessApp.Data;

public sealed class BookingRepository
{
    private const int TotalSeats = 50;
    private readonly string _connectionString;
    private readonly ILogger<BookingRepository> _logger;

    public BookingRepository(IConfiguration configuration, ILogger<BookingRepository> logger)
    {
        _connectionString = configuration.GetConnectionString("DefaultConnection")
            ?? "Data Source=/home/app.db";
        _logger = logger;
    }

    public async Task InitializeAsync()
    {
        var directory = Path.GetDirectoryName(_connectionString.Replace("Data Source=", "", StringComparison.OrdinalIgnoreCase));
        if (!string.IsNullOrWhiteSpace(directory)) Directory.CreateDirectory(directory);
        await using var connection = Open();
        await connection.OpenAsync();
        await ExecuteAsync(connection, SchemaSql);
        await SeedAsync(connection);
    }

    public async Task<IReadOnlyList<Showing>> GetAvailableShowingsAsync()
    {
        await using var connection = Open();
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText = """
            SELECT s.ShowingID, f.FilmTitle, s.ShowingDate, s.ShowingTime
            FROM Showing s INNER JOIN Film f ON f.FilmId = s.FilmId
            WHERE date(s.ShowingDate) >= date('now')
            ORDER BY f.FilmTitle, s.ShowingDate, s.ShowingTime;
            """;
        var result = new List<Showing>();
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
            result.Add(new Showing(reader.GetInt32(0), reader.GetString(1),
                reader.GetDateTime(2), reader.GetDateTime(3)));
        return result;
    }

    public async Task<(int BookingCount, int SeatCount, int SeatsLeft)> GetAvailabilityAsync(int showingId)
    {
        await using var connection = Open();
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText = "SELECT COUNT(*), COALESCE(SUM(Seats), 0) FROM Booking WHERE ShowingId = $showingId;";
        command.Parameters.AddWithValue("$showingId", showingId);
        await using var reader = await command.ExecuteReaderAsync();
        await reader.ReadAsync();
        var count = reader.GetInt32(0);
        var seats = reader.GetInt32(1);
        return (count, seats, Math.Max(0, TotalSeats - seats));
    }

    public async Task<BookingResult> CreateBookingAsync(int showingId, int customerId, int seats)
    {
        if (seats is < 1 or > TotalSeats) return new(false, "Choose between 1 and 50 seats.");
        await using var connection = Open();
        await connection.OpenAsync();
        await using var transaction = await connection.BeginTransactionAsync();
        await using var check = connection.CreateCommand();
        check.Transaction = transaction;
        check.CommandText = "SELECT COALESCE(SUM(Seats), 0) FROM Booking WHERE ShowingId = $showingId;";
        check.Parameters.AddWithValue("$showingId", showingId);
        var booked = Convert.ToInt32(await check.ExecuteScalarAsync());
        if (booked + seats > TotalSeats)
        {
            await transaction.RollbackAsync();
            return new(false, $"Sorry - we only have {TotalSeats - booked} seats available.");
        }
        await using var insert = connection.CreateCommand();
        insert.Transaction = transaction;
        insert.CommandText = "INSERT INTO Booking (ShowingId, CustId, Seats) VALUES ($showingId, $customerId, $seats);";
        insert.Parameters.AddWithValue("$showingId", showingId);
        insert.Parameters.AddWithValue("$customerId", customerId);
        insert.Parameters.AddWithValue("$seats", seats);
        await insert.ExecuteNonQueryAsync();
        await transaction.CommitAsync();
        return new(true, "Booking accepted.");
    }

    public async Task<IReadOnlyList<Customer>> GetCustomersAsync()
    {
        await using var connection = Open();
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText = "SELECT CustID, CustName FROM Customer ORDER BY CustName;";
        var result = new List<Customer>();
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync()) result.Add(new(reader.GetInt32(0), reader.GetString(1)));
        return result;
    }

    private SqliteConnection Open() => new(_connectionString);
    private static async Task ExecuteAsync(SqliteConnection connection, string sql)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync();
    }
    private static async Task SeedAsync(SqliteConnection connection)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = """
            INSERT OR IGNORE INTO Film (FilmId, FilmTitle) VALUES
              (1, 'The Azure Horizon'), (2, 'GitHub Galaxy'), (3, 'A Night at the Cinema');
            INSERT OR IGNORE INTO Customer (CustID, CustName) VALUES
              (1, 'Alex Morgan'), (2, 'Jamie Lee'), (3, 'Taylor Smith');
            INSERT OR IGNORE INTO Showing (ShowingID, FilmId, ShowingDate, ShowingTime) VALUES
              (1, 1, date('now', '+1 day'), '18:30'), (2, 2, date('now', '+2 day'), '20:00'),
              (3, 3, date('now', '+3 day'), '17:00');
            """;
        await command.ExecuteNonQueryAsync();
    }

    private const string SchemaSql = """
        CREATE TABLE IF NOT EXISTS Film (FilmId INTEGER PRIMARY KEY, FilmTitle TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS Customer (CustID INTEGER PRIMARY KEY, CustName TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS Showing (ShowingID INTEGER PRIMARY KEY, FilmId INTEGER NOT NULL,
          ShowingDate TEXT NOT NULL, ShowingTime TEXT NOT NULL,
          FOREIGN KEY (FilmId) REFERENCES Film(FilmId));
        CREATE TABLE IF NOT EXISTS Booking (BookingId INTEGER PRIMARY KEY AUTOINCREMENT,
          ShowingId INTEGER NOT NULL, CustId INTEGER NOT NULL, Seats INTEGER NOT NULL CHECK (Seats > 0),
          FOREIGN KEY (ShowingId) REFERENCES Showing(ShowingID),
          FOREIGN KEY (CustId) REFERENCES Customer(CustID));
        """;
}
