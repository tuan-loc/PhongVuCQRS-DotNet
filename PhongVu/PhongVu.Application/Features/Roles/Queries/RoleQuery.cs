using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Roles.Queries
{
    public record RoleQueryRequest(int id) : IRequest<Role>;

    public class RoleQueryHandler : BaseService, IRequestHandler<RoleQueryRequest, Role>
    {
        public RoleQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<Role> Handle(RoleQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.RoleRepository.GetById(request.id));
        }
    }
}
