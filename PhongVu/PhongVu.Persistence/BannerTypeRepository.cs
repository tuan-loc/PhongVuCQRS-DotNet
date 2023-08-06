using Dapper;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;
using System.Data;

namespace PhongVu.Persistence
{
    internal class BannerTypeRepository : BaseRepository, IBannerTypeRepository
    {
        public BannerTypeRepository(IDbConnection connection) : base(connection)
        {
        }

        public int Add(BannerType entity)
        {
            string sql = "INSERT INTO BannerType (TypeName) VALUES (@Name)";
            return connection.Execute(sql, new { Name = entity.TypeName });
        }

        public int Delete(int id)
        {
            string sql = "DELETE FROM BannerType WHERE TypeId = @Id";
            return connection.Execute(sql, new { Id = id });
        }

        public int Edit(BannerType entity)
        {
            string sql = "UPDATE BannerType SET TypeName = @Name WHERE TypeId = @Id";
            return connection.Execute(sql, new
            {
                Id = entity.TypeId,
                Name = entity.TypeName
            });
        }

        public IEnumerable<BannerType> GetAll()
        {
            string sql = "SELECT * FROM BannerType";
            return connection.Query<BannerType>(sql);
        }

        public BannerType GetById(int id)
        {
            string sql = "SELECT * FROM BannerType WHERE TypeId = @Id";
            return connection.QuerySingleOrDefault<BannerType>(sql, new { Id = id });
        }
    }
}
