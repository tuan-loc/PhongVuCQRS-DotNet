using Dapper;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;
using System.Data;

namespace PhongVu.Persistence
{
    internal class ProductRepository : BaseRepository, IProductRepository
    {
        public ProductRepository(IDbConnection connection) : base(connection)
        {
        }

        public int Add(Product entity)
        {
            throw new NotImplementedException();
        }

        public int Delete(int id)
        {
            throw new NotImplementedException();
        }

        public int Edit(Product entity)
        {
            throw new NotImplementedException();
        }

        public IEnumerable<Product> GetAll()
        {
            string sql = "SELECT * FROM Product";
            return connection.Query<Product>(sql);
        }

        public Product GetById(int id)
        {
            throw new NotImplementedException();
        }
    }
}
