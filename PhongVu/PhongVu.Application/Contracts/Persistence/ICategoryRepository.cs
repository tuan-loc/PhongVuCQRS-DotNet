using PhongVu.Domain.Entities;

namespace PhongVu.Application.Contracts.Persistence
{
	public interface ICategoryRepository : IRepository<Category, short>
	{
		IEnumerable<Category> GetParents();
	}
}
