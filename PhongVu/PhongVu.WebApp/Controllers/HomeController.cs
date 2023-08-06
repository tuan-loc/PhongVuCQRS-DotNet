using Microsoft.AspNetCore.Mvc;
using PhongVu.Application.Features.Banners.Queries;
using PhongVu.Application.Features.Categories.Queries;
using PhongVu.Application.Features.Products.Queries;
using PhongVu.Domain.Entities;

namespace PhongVu.WebApp.Controllers
{
	public class HomeController : BaseController
	{
		public async Task<IActionResult> Index()
		{
			ViewBag.Categories = await Mediator.Send(new CategoriesQueryRequest());
			ViewBag.Banners = await Mediator.Send(new BannersQueryRequest());
			IEnumerable<Product> products = await Mediator.Send(new ProductsQueryRequest());
            return View(products);
		}

		public async Task<IActionResult> Category(short id)
		{
			Category category = await Mediator.Send(new CategoryQueryRequest(id));
			if(category != null)
			{
				category.Products = (List<Product>)await Mediator.Send(new ProductsByCategoryQueryRequest(id));
			}
			return View(category);
		}

		public async Task<IActionResult> Details(int id)
		{
			Product obj = await Mediator.Send(new ProductQueryRequest(id));
			return View(obj);
			//if(obj != null)
			//{
			//	ViewData["title"] = obj.ProductName;
			//	return View(obj);
			//}
			//return Redirect("/");
		}
	}
}
