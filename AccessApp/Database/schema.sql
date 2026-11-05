CREATE TABLE Film (FilmId int NOT NULL PRIMARY KEY, FilmTitle nvarchar(50) NOT NULL);
CREATE TABLE Customer (CustID int NOT NULL PRIMARY KEY, CustName nvarchar(50) NOT NULL);
CREATE TABLE Showing (ShowingID int NOT NULL PRIMARY KEY, FilmId int NOT NULL REFERENCES Film(FilmId),
  ShowingDate date NOT NULL, ShowingTime time NOT NULL);
CREATE TABLE Booking (BookingId int IDENTITY(1,1) NOT NULL PRIMARY KEY, ShowingId int NOT NULL REFERENCES Showing(ShowingID),
  CustId int NOT NULL REFERENCES Customer(CustID), Seats smallint NOT NULL CHECK (Seats > 0));
GO
CREATE OR ALTER PROCEDURE dbo.FilmsAvailable AS
BEGIN
  SET NOCOUNT ON;
  SELECT s.ShowingID, f.FilmTitle, s.ShowingDate, s.ShowingTime
  FROM Showing s INNER JOIN Film f ON f.FilmId=s.FilmId
  WHERE s.ShowingDate >= CAST(GETDATE() AS date)
  ORDER BY f.FilmTitle, s.ShowingDate, s.ShowingTime;
END;
GO
CREATE OR ALTER PROCEDURE dbo.GetShowingAvailability @ShowingId int AS
BEGIN
  SET NOCOUNT ON;
  SELECT COUNT(*) AS BookingCount, COALESCE(SUM(Seats),0) AS SeatCount,
    50-COALESCE(SUM(Seats),0) AS SeatsLeft FROM Booking WHERE ShowingId=@ShowingId;
END;
GO
CREATE OR ALTER PROCEDURE dbo.CreateBooking @ShowingId int, @CustId int, @Seats smallint AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;
  BEGIN TRANSACTION;
  IF @Seats < 1 OR @Seats > 50 OR
     (SELECT COALESCE(SUM(Seats),0) FROM Booking WITH (UPDLOCK,HOLDLOCK) WHERE ShowingId=@ShowingId)+@Seats > 50
  BEGIN ROLLBACK; THROW 51000, 'Not enough seats available.', 1; END
  INSERT INTO Booking(ShowingId,CustId,Seats) VALUES(@ShowingId,@CustId,@Seats);
  COMMIT;
END;
GO
