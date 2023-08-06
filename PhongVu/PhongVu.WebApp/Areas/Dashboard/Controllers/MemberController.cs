using Microsoft.AspNetCore.Mvc;
using PhongVu.Application.Features.Member.Queries;
using PhongVu.Application.Features.Roles.Commands;
using PhongVu.Domain.Entities;
using PhongVu.WebApp.Controllers;

namespace PhongVu.WebApp.Areas.Dashboard.Controllers
{
    [Area("dashboard")]
    public class MemberController : BaseController
    {
        public async Task<IActionResult> Index()
        {
            return View(await Mediator.Send(new MembersQueryRequest()));
        }

        public async Task<IActionResult> Roles(string id)
        {
            ViewBag.roles = await Mediator.Send(new RolesByMemberQueryRequest(id));
            return View(await Mediator.Send(new MemberQueryRequest(id)));
        }

        [HttpPost]
        public async Task<IActionResult> AddRole(Role obj)
        {
            return View(await Mediator.Send(new CreateRoleCommandRequest(obj)));
        }


    }
}
