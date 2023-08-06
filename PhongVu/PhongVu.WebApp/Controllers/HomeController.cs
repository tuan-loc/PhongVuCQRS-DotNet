using Microsoft.AspNetCore.Mvc;
using PhongVu.Application.Features.Banners.Queries;
using PhongVu.Application.Features.Categories.Queries;
using PhongVu.Application.Features.Products.Queries;

namespace PhongVu.WebApp.Controllers
{
	public class HomeController : BaseController
	{
		public async Task<IActionResult> Index()
		{
			ViewBag.Categories = await Mediator.Send(new CategoriesQueryRequest());
			ViewBag.Banners = await Mediator.Send(new BannersQueryRequest());
			ViewBag.Products = await Mediator.Send(new ProductsQueryRequest());
            return View();
		}
	}
}
