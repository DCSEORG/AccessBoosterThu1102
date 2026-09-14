Option Compare Database
Option Explicit

Const TotalSeats = 50   'number of seats at each showing

'-------------------------------------------
Private Sub cmdMakeBooking_Click()
On Error GoTo Err_cmdMakeBooking_Click

'user has clicked on booking button, so there must be some seats left
'check that there are enough seats left

    If Seats > txtSeatsLeft Then
    'if not enough seats, show message and remove info from form
        MsgBox ("Sorry - we only have " & txtSeatsLeft & " seats available")
        Me.Undo
    Else
    'save the booking details
        DoCmd.DoMenuItem acFormBar, acRecordsMenu, acSaveRecord, , acMenuVer70
        MsgBox ("Booking Accepted")
        'refresh the availability on the form
        CalculateSeats
    End If

Exit_cmdMakeBooking_Click:
    Exit Sub

Err_cmdMakeBooking_Click:
If Err = 2501 Then
    'ignore Do Menu Item cancelled message - may happen if save is cancelled
Else
    MsgBox Err.Description
    Resume Exit_cmdMakeBooking_Click
End If
    
End Sub

'---------------------------------------
Private Sub Form_Load()
'when form opened, go to new record
    DoCmd.GoToRecord , , acNewRec
End Sub

'----------------------------------------------
Private Sub lstShowing_Click()
'user has selected a showing, so calculate seats
    CalculateSeats

'is the showing already fully booked?
    If txtSeatsLeft = 0 Then
    'message to say it's full and remove info from form
        MsgBox ("Sorry - this showing is full")
        Me.Undo
    Else
    'there are seats available, so enable the booking button
    'should also ask for user id!
        cmdMakeBooking.Enabled = True
    End If
End Sub

'-------------------------------------------------
Private Sub CalculateSeats()
'show the current availabity on the form
    txtBookingCount = DCount("ShowingId", "Booking", "ShowingId = Forms!Booking!ShowingId")
    If txtBookingCount = 0 Then
       txtSeatCount = 0
       txtSeatsLeft = TotalSeats
    Else
        txtSeatCount = DSum("Seats", "Booking", "ShowingId = Forms!Booking!ShowingId")
        txtSeatsLeft = TotalSeats - txtSeatCount
    End If
End Sub
