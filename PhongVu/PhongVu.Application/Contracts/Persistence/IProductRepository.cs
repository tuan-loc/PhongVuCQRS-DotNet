using PhongVu.Domain.Entities;

namespace PhongVu.Application.Contracts.Persistence
{
    public interface IProductRepository : IRepository<Product, int>
    {
        IEnumerable<Product> GetProductsByCategory(short id);
    }
}
