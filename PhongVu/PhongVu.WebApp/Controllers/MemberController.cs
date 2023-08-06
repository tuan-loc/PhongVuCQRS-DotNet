using Microsoft.AspNetCore.Mvc;

namespace PhongVu.WebApp.Controllers
{
    public class MemberController : BaseController
    {
        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Notification()
        {
            return View();
        }

        public IActionResult Order()
        {
            return View();
        }

        public IActionResult Address()
        {
            return View();
        }

        public IActionResult OrderDetail()
        {
            return View();
        }
    }
}
