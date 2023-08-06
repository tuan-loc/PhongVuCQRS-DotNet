using Dapper;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Application.Dto.MemberDto;
using PhongVu.Domain.Entities;
using System.Data;
using static Dapper.SqlMapper;

namespace PhongVu.Persistence
{
    public class MemberRepository : BaseRepository, IMemberRepository
    {
        public MemberRepository(IDbConnection connection) : base(connection)
        {
        }

        public int Add(Member entity)
        {
            throw new NotImplementedException();
        }

        public int AddMemberInRole(AddMemberInRoleDto obj)
        {
            return connection.Execute("AddMemberInRole", new
            {
                MemberId = obj.MemberId,
                RoleId = obj.RoleId
            }, commandType: CommandType.StoredProcedure);
        }

        public int Delete(string id)
        {
            throw new NotImplementedException();
        }

        public int Edit(Member entity)
        {
            throw new NotImplementedException();
        }

        public IEnumerable<Member> GetAll()
        {
            throw new NotImplementedException();
        }

        public Member GetById(string id)
        {
            string sql = "SELECT * FROM Member WHERE MemberId = @Id";
            return connection.QuerySingleOrDefault(sql, new { Id = id });
        }

        public IEnumerable<Role> GetRolesByMember(string id)
        {
            return connection.Query<Role>("GetRolesByMember", new { Id = id }, commandType: CommandType.StoredProcedure);
        }
    }
}
