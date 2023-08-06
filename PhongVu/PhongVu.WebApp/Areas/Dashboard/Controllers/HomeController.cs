using Microsoft.AspNetCore.Mvc;
using PhongVu.WebApp.Controllers;

namespace PhongVu.WebApp.Areas.Dashboard.Controllers
{
    [Area("dashboard")]
    public class HomeController : BaseController
    {
        public IActionResult Index()
        {
            return View();
        }
    }
}
