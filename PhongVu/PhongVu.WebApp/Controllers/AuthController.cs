using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhongVu.Application.Dto.AuthDto;
using PhongVu.Application.Features.Auth.Commands;
using PhongVu.Infrastructure;
using System.Security.Claims;

namespace PhongVu.WebApp.Controllers
{
    public class AuthController : BaseController
    {
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Register()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Register(RegisterDto obj)
        {
            obj.MemberId = PhongVu.Infrastructure.Helper.RandomString(32);
            obj.RoleId = 1;
            int ret = await Mediator.Send(new RegisterCommandRequest(obj));
            if (ret > 0)
            {
                return Redirect("/auth/login");
            }
            string[] arr = { $"Username {obj.UserName} exists", "Inserted Failed" };
            ModelState.AddModelError("error", arr[ret + 1]);
            return View(obj);
        }

        public IActionResult Login()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Login(LoginDto obj, string returnUrl = null)
        {
            PhongVu.Domain.Entities.Member member = await Mediator.Send(new LoginCommandRequest(obj));
            Console.WriteLine(member.MemberId);
            if (member != null)
            {
                List<Claim> claims = new List<Claim>()
                {
                    new Claim(ClaimTypes.NameIdentifier, member.MemberId),
                    new Claim(ClaimTypes.Name, member.Username),
                    new Claim(ClaimTypes.Email, member.Email),
                    new Claim(ClaimTypes.GivenName, member.Fullname),
                    new Claim(ClaimTypes.Gender, member.Gender ? "Female" : "Male")
                };
                ClaimsIdentity identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                ClaimsPrincipal principal = new ClaimsPrincipal(identity);
                AuthenticationProperties properties = new AuthenticationProperties
                {
                    IsPersistent = obj.Remember
                };
                await HttpContext.SignInAsync(principal, properties);
                if (string.IsNullOrEmpty(returnUrl))
                {
                    return Redirect("/");
                }
                else
                {
                    return Redirect(returnUrl);
                }
            }
            ModelState.AddModelError("error", "Login Failed");
            return View(obj);
        }

        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            return Redirect("/auth/login");
        }

        public IActionResult Change()
        {
            return View();
        }

        [Authorize]
        [HttpPost]
        public async Task<IActionResult> Change(ChangeDto obj)
        {
            obj.Id = User.FindFirstValue(ClaimTypes.NameIdentifier);
            int ret = await Mediator.Send(new ChangeCommandRequest(obj));
            if (ret > 0)
            {
                return await Logout();
            }
            ModelState.AddModelError("error", "Old Password Failed");
            return View(obj);
        }
    }
}
