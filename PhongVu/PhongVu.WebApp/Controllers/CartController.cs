using Microsoft.AspNetCore.Mvc;
using PhongVu.Application.Features.Products.Queries;
using PhongVu.Domain.Entities;
using System.Text.Json;

namespace PhongVu.WebApp.Controllers
{
    public class CartController : BaseController
    {
        public IActionResult Index()
        {
            Dictionary<int, Cart>? dict = HttpContext.Session.Get<Dictionary<int, Cart>>("cart");
            if(dict != null)
            {
                return View(dict.Values.ToList());
            }
            return Redirect("/");
        }

        [HttpPost]
        public async Task<IActionResult> Add(Cart obj)
        {
            Product product = await Mediator.Send(new ProductQueryRequest(obj.ProductId));
            if(product != null)
            {
                obj.ProductName = product.ProductName;
                obj.ImageUrl = product.ImageUrl;
                obj.Price = product.SalePrice;

                Dictionary<int, Cart>? dict = HttpContext.Session.Get<Dictionary<int, Cart>>("cart");
                if (dict != null)
                {
                    if (dict.ContainsKey(obj.ProductId))
                    {
                        dict[obj.ProductId].Quantity += obj.Quantity;
                    }
                    else
                    {
                        dict[obj.ProductId] = obj;
                    }
                }
                else
                {
                    dict = new Dictionary<int, Cart>
                    {
                        {obj.ProductId, obj}
                    };
                }
                HttpContext.Session.Set("cart", dict);
                return Redirect("/cart");
            }
            return Redirect("/");
        }

        public IActionResult Delete(int id)
        {
            Dictionary<int, Cart>? dict = HttpContext.Session.Get<Dictionary<int, Cart>>("cart");
            if(dict != null && dict.ContainsKey(id))
            {
                HttpContext.Session.Set("cart", dict);
            }
            return Redirect("/cart");
        }

        public IActionResult Clear()
        {
            HttpContext.Session.Remove("cart");
            return Redirect("/");
        }

        [HttpPost]
        public IActionResult Edit(Cart obj)
        {
            Dictionary<int, Cart>? dict = HttpContext.Session.Get<Dictionary<int, Cart>>("cart");
            if(dict != null && dict.ContainsKey(obj.ProductId))
            {
                dict[obj.ProductId].Quantity = obj.Quantity;
                HttpContext.Session.Set("cart", dict);
                return Json(1);
            }
            return Json(0);
        }

        public IActionResult Checkout()
        {
            return View();
        }

        public IActionResult InfomationRecieve()
        {
            return View();
        }
    }
}
