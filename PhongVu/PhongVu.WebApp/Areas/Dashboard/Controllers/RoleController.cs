using Microsoft.AspNetCore.Mvc;
using PhongVu.Application.Features.Roles.Commands;
using PhongVu.Application.Features.Roles.Queries;
using PhongVu.Domain.Entities;
using PhongVu.WebApp.Controllers;

namespace PhongVu.WebApp.Areas.Dashboard.Controllers
{
    [Area("dashboard")]
    public class RoleController : BaseController
    {
        public async Task<IActionResult> Index()
        {
            return View(await Mediator.Send(new RolesQueryRequest()));
        }

        public IActionResult Add()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Add(Role obj)
        {
            Random random = new Random();
            obj.RoleId = random.Next();
            int ret = await Mediator.Send(new CreateRoleCommandRequest(obj));
            if(ret > 0)
            {
                return Redirect("/dashboard/role");
            }
            return Redirect("/dashboard/role/error");
        }

        public async Task<IActionResult> Detail(int id)
        {
            return View(await Mediator.Send(new RoleQueryRequest(id)));
        }

        [HttpPost]
        public async Task<IActionResult> Delete(int id)
        {
            int ret = await Mediator.Send(new DeleteRoleCommandRequest(id));
            if(ret > 0)
            {
                return Redirect("/dashboard/role");
            }
            return Redirect("/dashboard/role/error");
        }
    }
}
