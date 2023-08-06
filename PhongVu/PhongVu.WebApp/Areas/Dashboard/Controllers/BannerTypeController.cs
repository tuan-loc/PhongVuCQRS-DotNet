using Microsoft.AspNetCore.Mvc;
using PhongVu.Application.Features.BannerTypes.Commands;
using PhongVu.Application.Features.BannerTypes.Queries;
using PhongVu.Domain.Entities;
using PhongVu.WebApp.Controllers;

namespace PhongVu.WebApp.Areas.Dashboard.Controllers
{
    [Area("dashboard")]
    public class BannerTypeController : BaseController
    {
        public async Task<IActionResult> Index()
        {
            IEnumerable<BannerType> bannerTypes = await Mediator.Send(new BannerTypesQueryRequest());
            return View(bannerTypes);
        }

        public IActionResult Add()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> Add(BannerType obj)
        {
            int ret = await Mediator.Send(new CreateBannerTypeCommandRequest(obj));
            if (ret > 0)
            {
                return Redirect("/dashboard/bannerType");
            }
            return Redirect("/dashboard/bannerType/error");
        }

        public async Task<IActionResult> Delete(int id)
        {
            BannerType bannerType = await Mediator.Send(new BannerTypeQueryRequest(id));
            return View(bannerType);
        }

        [HttpPost]
        public async Task<IActionResult> Delete(BannerType bannerType)
        {
            int ret = await Mediator.Send(new DeleteBannerTypeCommandRequest(bannerType.TypeId));
            if (ret > 0)
            {
                return Redirect("/dashboard/bannerType");
            }
            return Redirect("/dashboard/bannerType/error");
        }

        public async Task<IActionResult> Edit(int id)
        {
            BannerType bannerType = await Mediator.Send(new BannerTypeQueryRequest(id));
            return View(bannerType);
        }

        [HttpPost]
        public async Task<IActionResult> Edit(BannerType bannerType)
        {
            int ret = await Mediator.Send(new UpdateBannerTypeCommandRequest(bannerType));
            if (ret > 0)
            {
                return Redirect("/dashboard/bannerType");
            }
            return Redirect("/dashboard/bannerType/error");
        }
    }
}
