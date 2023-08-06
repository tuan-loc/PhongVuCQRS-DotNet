using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Roles.Commands
{
    public record UpdateRoleCommandRequest(Role role) : IRequest<int>;

    public class UpdateRoleCommandHandler : BaseService, IRequestHandler<UpdateRoleCommandRequest, int>
    {
        public UpdateRoleCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(UpdateRoleCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.RoleRepository.Edit(request.role));
        }
    }
}
