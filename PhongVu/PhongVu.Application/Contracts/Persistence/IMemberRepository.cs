using PhongVu.Application.Dto.MemberDto;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Contracts.Persistence
{
    public interface IMemberRepository : IRepository<Member, string>
    {
        int AddMemberInRole(AddMemberInRoleDto obj);
        IEnumerable<Role> GetRolesByMember(string id);
    }
}
