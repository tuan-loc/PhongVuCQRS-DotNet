using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Roles.Queries
{
    public class RolesQueryRequest : IRequest<IEnumerable<Role>>
    {
    }

    public class RolesQueryHandler : BaseService, IRequestHandler<RolesQueryRequest, IEnumerable<Role>>
    {
        public RolesQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<IEnumerable<Role>> Handle(RolesQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.RoleRepository.GetAll());
        }
    }
}
