using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Application.Features.Member.Queries
{
    public record RolesByMemberQueryRequest(string memberId) : IRequest<IEnumerable<PhongVu.Domain.Entities.Role>>
    {
    }

    public class RolesByMemberQueryHandler : BaseService, IRequestHandler<RolesByMemberQueryRequest, IEnumerable<PhongVu.Domain.Entities.Role>>
    {
        public RolesByMemberQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<IEnumerable<PhongVu.Domain.Entities.Role>> Handle(RolesByMemberQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.MemberRepository.GetRolesByMember(request.memberId));
        }
    }
}
