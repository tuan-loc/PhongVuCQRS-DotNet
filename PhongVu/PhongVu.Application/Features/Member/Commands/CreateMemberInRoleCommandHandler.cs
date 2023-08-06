using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Application.Dto.MemberDto;

namespace PhongVu.Application.Features.Member.Commands
{
    public record CreateMemberInRoleCommandRequest(AddMemberInRoleDto memberInRoleDto) : IRequest<int>;

    public class CreateMemberInRoleCommandHandler : BaseService, IRequestHandler<CreateMemberInRoleCommandRequest, int>
    {
        public CreateMemberInRoleCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(CreateMemberInRoleCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.MemberRepository.AddMemberInRole(request.memberInRoleDto));
        }

    }
}
