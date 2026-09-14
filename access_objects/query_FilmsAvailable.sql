-- Query: FilmsAvailable
SELECT Showing.ShowingID, Film.FilmTitle, Showing.ShowingDate, Showing.ShowingTime
FROM Film INNER JOIN Showing ON Film.FilmId=Showing.FilmId
WHERE (((Showing.ShowingDate)>=Date()))
ORDER BY Film.FilmTitle, Showing.ShowingDate, Showing.ShowingTime;

