using Microsoft.AspNetCore.Mvc;
using PhongVu.Application.Features.Banners.Commands;
using PhongVu.Application.Features.Banners.Queries;
using PhongVu.Application.Features.BannerTypes.Queries;
using PhongVu.Domain.Entities;
using PhongVu.Infrastructure;
using PhongVu.WebApp.Controllers;

namespace PhongVu.WebApp.Areas.Dashboard.Controllers
{
    [Area("dashboard")]
    public class BannerController : BaseController
    {
        public async Task<IActionResult> Index()
        {
            return View(await Mediator.Send(new BannersQueryRequest()));
        }

        public async Task<IActionResult> Add()
        {
            IEnumerable<BannerType> bannerTypes = await Mediator.Send(new BannerTypesQueryRequest());
            return View(bannerTypes);
        }

        [HttpPost]
        public async Task<IActionResult> Add(Banner banner, IFormFile f)
        {
            if (f != null && !string.IsNullOrEmpty(f.FileName))
            {
                string ext = Path.GetExtension(f.FileName);
                string fileName = PhongVu.Infrastructure.Helper.RandomString(32 - ext.Length) + ext;
                banner.ImageUrl = fileName;
                string path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "banners");

                if (!Directory.Exists(path))
                {
                    Directory.CreateDirectory(path);
                }

                using (Stream stream = new FileStream(Path.Combine(path, fileName), FileMode.Create))
                {
                    f.CopyTo(stream);
                }

                int ret = await Mediator.Send(new CreateBannerCommandRequest(banner));
                if (ret > 0)
                {
                    return Redirect("/dashboard/banner");
                }
            }
            return Redirect("/dashboard/banner/error");
        }

        public async Task<IActionResult> Delete(int id)
        {
            Banner banner = await Mediator.Send(new BannerQueryRequest(id));
            return View(banner);
        }

        [HttpPost]
        public async Task<IActionResult> Delete(Banner obj)
        {
            int ret = await Mediator.Send(new DeleteBannerCommandRequest(obj.BannerId));
            if(ret > 0)
            {
                string path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "banners");
                System.IO.File.Delete(Path.Combine(path, obj.ImageUrl));
            }
            return Redirect("/dashboard/banner");
        }

        public async Task<IActionResult> Edit(int id)
        {
            ViewBag.BannerType = await Mediator.Send(new BannerTypesQueryRequest());
            return View(await Mediator.Send(new BannerQueryRequest(id)));
        }

        [HttpPost]
        public async Task<IActionResult> Edit(Banner obj, IFormFile f)
        {
            if(f != null && !string.IsNullOrEmpty(f.FileName))
            {
                string ext = Path.GetExtension(f.FileName);
                string fileName = PhongVu.Infrastructure.Helper.RandomString(32 - ext.Length) + ext;
                string path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "banners");
                System.IO.File.Delete(Path.Combine(path, obj.ImageUrl));
                using(Stream stream = new FileStream(Path.Combine(path, fileName), FileMode.Create))
                {
                    f.CopyTo(stream);
                }
                obj.ImageUrl = fileName;
            }
            int ret = await Mediator.Send(new UpdateBannerCommandRequest(obj));
            if(ret > 0)
            {
                return Redirect("/dashboard/banner");
            }
            return Redirect("/dashboard/banner/error");
        }
    }
}
