using Dapper;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;
using System.Data;

namespace PhongVu.Persistence
{
	public class CategoryRepository : BaseRepository, ICategoryRepository
	{
		public CategoryRepository(IDbConnection connection) : base(connection)
		{
		}

		public int Add(Category entity)
		{
			string sql = "INSERT INTO Category (CategoryName, ImageUrl, ParentId) VALUES (@CategoryName, @ImageUrl, @ParentId)";
			return connection.Execute(sql, new
			{
				CategoryName = entity.CategoryName,
				ImageUrl = entity.ImageUrl,
				ParentId = entity.ParentId,
			});
		}

		public int Delete(short id)
		{
            string sql = "DELETE FROM Category WHERE CategoryId = @Id";
            return connection.Execute(sql, new { Id = id });
        }

		public int Edit(Category entity)
		{
			return connection.Execute("EditCategory", new

            {
				CategoryId = entity.CategoryId,
				CategoryName = entity.CategoryName,
				ImageUrl = entity.ImageUrl,
				ParentId = entity.ParentId,
			}, commandType: CommandType.StoredProcedure);
		}

		public IEnumerable<Category> GetAll()
		{
			return connection.Query<Category>("SELECT * FROM Category");
		}

		public Category GetById(short id)
		{
			return connection.QuerySingleOrDefault<Category>("SELECT * FROM Category WHERE CategoryId = @Id", new { Id = id });
		}

        public IEnumerable<Category> GetParents()
        {
			string sql = "SELECT * FROM Category WHERE Category.ParentId IS NULL;";
			return connection.Query<Category>(sql);
        }
    }
}