using Dapper;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;
using System.Data;

namespace PhongVu.Persistence
{
    public class RoleRepository : BaseRepository, IRoleRepository
    {
        public RoleRepository(IDbConnection connection) : base(connection)
        {
        }

        public int Add(Role entity)
        {
            string sql = "INSERT INTO Role(RoleId, RoleName) VALUES (@Id, @Name)";
            return connection.Execute(sql, new
            {
                Id = entity.RoleId,
                Name = entity.RoleName
            });
        }

        public int Delete(int id)
        {
            string sql = "DELETE FROM Role WHERE RoleId = @Id";
            return connection.Execute(sql, new { Id = id });
        }

        public int Edit(Role entity)
        {
            string sql = "UPDATE Role SET RoleName = @Name WHERE RoleId = @Id";
            return connection.Execute(sql, new
            {
                Name = entity.RoleName,
                Id = entity.RoleId,
            });
        }

        public IEnumerable<Role> GetAll()
        {
            string sql = "SELECT * FROM Role";
            return connection.Query<Role>(sql);
        }

        public Role GetById(int id)
        {
            string sql = "SELECT * FROM Role WHERE RoleId = @Id";
            return connection.QuerySingleOrDefault<Role>(sql, new { Id = id });
        }
    }
}
