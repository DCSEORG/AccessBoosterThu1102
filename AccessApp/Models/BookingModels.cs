namespace AccessApp.Models;

public sealed record Showing(int ShowingId, string FilmTitle, DateTime ShowingDate, DateTime ShowingTime);
public sealed record Booking(int BookingId, int ShowingId, int CustId, int Seats);
public sealed record Customer(int CustId, string CustName);
public sealed record BookingResult(bool Success, string Message);
