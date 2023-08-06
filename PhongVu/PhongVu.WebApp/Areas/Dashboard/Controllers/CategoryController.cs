using Microsoft.AspNetCore.Mvc;
using PhongVu.Application.Dto.CategoryDto;
using PhongVu.Application.Features.Banners.Commands;
using PhongVu.Application.Features.Categories.Commands;
using PhongVu.Application.Features.Categories.Queries;
using PhongVu.Domain.Entities;
using PhongVu.Infrastructure;
using PhongVu.WebApp.Controllers;

namespace PhongVu.WebApp.Areas.Dashboard.Controllers
{
    [Area("dashboard")]
    public class CategoryController : BaseController
    {
        public async Task<IActionResult> Index()
        {
            IEnumerable<Category> categories = await Mediator.Send(new CategoriesQueryRequest());
            return View(categories);
        }

        public async Task<IActionResult> Add()
        {
            IEnumerable<Category> categories = await Mediator.Send(new CategoriesQueryRequest());
            return View(categories);
        }

        [HttpPost]
        public async Task<IActionResult> Add(CategoryDto categoryDto, IFormFile f)
        {
            if(f != null && !string.IsNullOrEmpty(f.FileName))
            {
                string ext = Path.GetExtension(f.FileName);
                string fileName = PhongVu.Infrastructure.Helper.RandomString(32 - ext.Length) + ext;
                categoryDto.ImageUrl = fileName;
                string path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "categories");

                if (!Directory.Exists(path))
                {
                    Directory.CreateDirectory(path);
                }

                using(Stream stream = new FileStream(Path.Combine(path, fileName), FileMode.Create))
                {
                    f.CopyTo(stream);
                }

                int ret = await Mediator.Send(new CreateCategoryCommandRequest(categoryDto));
                if (ret > 0)
                {
                    return Redirect("/dashboard/category");
                }
            }
            return Redirect("/dashboard/category/error");
        }

        public async Task<IActionResult> Edit(short id)
        {
            return View(await Mediator.Send(new CategoryQueryRequest(id)));
        }

        [HttpPost]
        public async Task<IActionResult> Edit(Category obj, IFormFile f)
        {
            if (f != null && !string.IsNullOrEmpty(f.FileName))
            {
                string ext = Path.GetExtension(f.FileName);
                string fileName = PhongVu.Infrastructure.Helper.RandomString(32 - ext.Length) + ext;
                string path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "categories");
                if (obj.ImageUrl != null)
                {
                    System.IO.File.Delete(Path.Combine(path, obj.ImageUrl));
                }
                using (Stream stream = new FileStream(Path.Combine(path, fileName), FileMode.Create))
                {
                    f.CopyTo(stream);
                }
                obj.ImageUrl = fileName;
            }
            int ret = await Mediator.Send(new UpdateCategoryCommandRequest(obj));
            if (ret > 0)
            {
                return Redirect("/dashboard/category");
            }
            return Redirect("/dashboard/category/error");
        }

        public async Task<IActionResult> Delete(short id)
        {
            return View(await Mediator.Send(new CategoryQueryRequest(id)));
        }

        [HttpPost]
        public async Task<IActionResult> Delete(Category obj)
        {
            int ret = await Mediator.Send(new DeleteCategoryCommandRequest(obj.CategoryId));
            if (ret > 0 && obj.ImageUrl != null)
            {
                string path = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "categories");
                System.IO.File.Delete(Path.Combine(path, obj.ImageUrl));
            }
            return Redirect("/dashboard/category");
        }
    }
}
