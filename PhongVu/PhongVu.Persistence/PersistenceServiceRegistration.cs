using Microsoft.Extensions.DependencyInjection;
using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Persistence
{
	public static class PersistenceServiceRegistration
	{
		public static IServiceCollection AddPersistence(this IServiceCollection services, string connectionString)
		{
			services.AddScoped<ISiteProvider>(p => new SiteProvider(connectionString));
			return services;
		}
	}
}
