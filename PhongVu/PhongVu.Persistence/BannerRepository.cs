using Dapper;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;
using System.Data;

namespace PhongVu.Persistence
{
    public class BannerRepository : BaseRepository, IBannerRepository
    {
        public BannerRepository(IDbConnection connection) : base(connection)
        {
        }

        public int Add(Banner entity)
        {
            string sql = "INSERT INTO Banner (BannerName, ImageUrl, BannerTypeId) VALUES (@BannerName, @ImageUrl, @BannerTypeId)";
            return connection.Execute(sql, new
            {
                BannerName = entity.BannerName,
                ImageUrl = entity.ImageUrl,
                BannerTypeId = entity.BannerTypeId,
            });
        }

        public int Delete(int id)
        {
            string sql = "DELETE FROM Banner WHERE BannerId = @Id";
            return connection.Execute(sql, new { Id = id });
        }

        public int Edit(Banner entity)
        {
            return connection.Execute("EditBanner", new
            {
                BannerId = entity.BannerId,
                BannerName = entity.BannerName,
                ImageUrl = entity.ImageUrl,
                BannerTypeId = entity.BannerTypeId,
            }, commandType: CommandType.StoredProcedure);
        }

        public IEnumerable<Banner> GetAll()
        {
            string sql = "SELECT Banner.*, BannerType.TypeName AS BannerTypeName FROM Banner JOIN BannerType ON Banner.BannerTypeId = BannerType.TypeId;";
            return connection.Query<Banner>(sql);
        }

        public Banner GetById(int id)
        {
            string sql = "SELECT Banner.*, BannerType.TypeName AS BannerTypeName FROM Banner JOIN BannerType ON Banner.BannerTypeId = BannerType.TypeId WHERE BannerId = @Id";
            return connection.QuerySingleOrDefault<Banner>(sql, new { Id = id });
        }
    }
}
