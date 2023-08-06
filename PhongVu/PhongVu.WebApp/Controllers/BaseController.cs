using MediatR;
using Microsoft.AspNetCore.Mvc;

namespace PhongVu.WebApp.Controllers
{
	public abstract class BaseController : Controller
	{
		IMediator mediator = null!;

		protected IMediator Mediator => mediator ??= HttpContext.RequestServices.GetRequiredService<IMediator>();
    }
}
