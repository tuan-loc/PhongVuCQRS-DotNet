using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Application.Features.Member.Queries
{
    public record MemberQueryRequest(string id) : IRequest<PhongVu.Domain.Entities.Member>;

    public class MemberQueryHandler : BaseService, IRequestHandler<MemberQueryRequest, PhongVu.Domain.Entities.Member>
    {
        public MemberQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<PhongVu.Domain.Entities.Member> Handle(MemberQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.MemberRepository.GetById(request.id));
        }
    }
}
