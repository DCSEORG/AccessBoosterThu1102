using AccessApp.Data;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddRazorPages();
builder.Services.AddSingleton<BookingRepository>();

var app = builder.Build();

// Database setup is deliberately non-fatal: the app can still serve diagnostics
// if a mounted App Service volume is temporarily unavailable.
try
{
    var repository = app.Services.GetRequiredService<BookingRepository>();
    await repository.InitializeAsync();
}
catch (Exception exception)
{
    app.Logger.LogError(exception, "Database initialization failed; continuing startup.");
}

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.MapRazorPages();
app.Run();
