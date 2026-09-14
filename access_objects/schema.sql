CREATE TABLE [Booking] (
  [BookingId] INTEGER,
  [ShowingId] INTEGER,
  [CustId] INTEGER,
  [Seats] SMALLINT
);

CREATE TABLE [Customer] (
  [CustID] INTEGER,
  [CustName] NVARCHAR(50)
);

CREATE TABLE [Film] (
  [FilmId] INTEGER,
  [FilmTitle] NVARCHAR(50)
);

CREATE TABLE [Showing] (
  [ShowingID] INTEGER,
  [FilmId] INTEGER,
  [ShowingDate] DATETIME,
  [ShowingTime] DATETIME
);

