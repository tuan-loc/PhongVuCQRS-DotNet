using Microsoft.AspNetCore.Authentication.Cookies;
using PhongVu.Application;
using PhongVu.Persistence;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(p =>
{
    p.LoginPath = "/auth/login";
    p.LogoutPath = "/auth/logout";
    p.ExpireTimeSpan = TimeSpan.FromDays(30);
});
builder.Services.AddMvc();
builder.Services.AddPersistence(builder.Configuration.GetConnectionString("PhongVu") ?? "");
builder.Services.AddApplication();

var app = builder.Build();

app.UseStaticFiles();
app.MapDefaultControllerRoute();
app.MapControllerRoute(name: "Dashboard", pattern: "{area:exists}/{controller=home}/{action=index}/{id?}");
app.Run();
