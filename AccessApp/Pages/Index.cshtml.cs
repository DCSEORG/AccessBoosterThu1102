using AccessApp.Data;
using AccessApp.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace AccessApp.Pages;

public class IndexModel(BookingRepository repository) : PageModel
{
    public IReadOnlyList<Showing> Showings { get; private set; } = [];
    public IReadOnlyList<Customer> Customers { get; private set; } = [];
    public Dictionary<int, (int BookingCount, int SeatCount, int SeatsLeft)> Availability { get; } = [];
    [BindProperty] public int ShowingId { get; set; }
    [BindProperty] public int CustomerId { get; set; }
    [BindProperty] public int Seats { get; set; }
    [TempData] public string? Message { get; set; }
    [TempData] public bool Success { get; set; }

    public async Task OnGetAsync() => await LoadAsync();
    public async Task<IActionResult> OnPostAsync()
    {
        var result = await repository.CreateBookingAsync(ShowingId, CustomerId, Seats);
        Message = result.Message;
        Success = result.Success;
        return RedirectToPage();
    }
    private async Task LoadAsync()
    {
        Showings = await repository.GetAvailableShowingsAsync();
        Customers = await repository.GetCustomersAsync();
        foreach (var showing in Showings) Availability[showing.ShowingId] = await repository.GetAvailabilityAsync(showing.ShowingId);
    }
}
