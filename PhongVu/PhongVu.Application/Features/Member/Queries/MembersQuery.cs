using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Application.Features.Member.Queries
{
    public class MembersQueryRequest : IRequest<IEnumerable<PhongVu.Domain.Entities.Member>>
    {
    }

    public class MembersQueryHandler : BaseService, IRequestHandler<MembersQueryRequest, IEnumerable<PhongVu.Domain.Entities.Member>>
    {
        public MembersQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<IEnumerable<PhongVu.Domain.Entities.Member>> Handle(MembersQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.MemberRepository.GetAll());
        }
    }
}
