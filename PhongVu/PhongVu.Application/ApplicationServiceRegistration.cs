using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace PhongVu.Application
{
	public static class ApplicationServiceRegistration
	{
		public static IServiceCollection AddApplication(this IServiceCollection services)
		{
			services.AddMediatR(p => p.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));
            services.AddAutoMapper(Assembly.GetExecutingAssembly());
            return services;
		}
	}
}