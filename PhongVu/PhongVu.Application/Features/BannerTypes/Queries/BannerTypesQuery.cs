using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.BannerTypes.Queries
{
    public class BannerTypesQueryRequest : IRequest<IEnumerable<BannerType>>
    {
    }

    public class BannerTypesQueryHandler : BaseService, IRequestHandler<BannerTypesQueryRequest, IEnumerable<BannerType>>
    {
        public BannerTypesQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<IEnumerable<BannerType>> Handle(BannerTypesQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerTypeRepository.GetAll());
        }
    }
}
