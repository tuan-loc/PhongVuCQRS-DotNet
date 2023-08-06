using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Roles.Commands
{
    public record CreateRoleCommandRequest(Role role) : IRequest<int>;

    public class CreateRoleCommandHandler : BaseService, IRequestHandler<CreateRoleCommandRequest, int>
    {
        public CreateRoleCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(CreateRoleCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.RoleRepository.Add(request.role));
        }
    }
}
