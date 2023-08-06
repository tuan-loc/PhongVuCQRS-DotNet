using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Application.Features.Roles.Commands
{
    public record DeleteRoleCommandRequest(int id) : IRequest<int>;

    public class DeleteRoleCommandHandler : BaseService, IRequestHandler<DeleteRoleCommandRequest, int>
    {
        public DeleteRoleCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(DeleteRoleCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.RoleRepository.Delete(request.id));
        }
    }
}
