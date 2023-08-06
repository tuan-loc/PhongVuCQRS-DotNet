using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Banners.Queries
{
    public class BannersQueryRequest : IRequest<IEnumerable<Banner>>
    {
    }

    public class BannersQueryHandler : BaseService, IRequestHandler<BannersQueryRequest, IEnumerable<Banner>>
    {
        public BannersQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<IEnumerable<Banner>> Handle(BannersQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerRepository.GetAll());
        }
    }
}
