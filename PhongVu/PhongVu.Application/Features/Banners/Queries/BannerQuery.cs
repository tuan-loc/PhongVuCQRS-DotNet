using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Banners.Queries
{
    public record BannerQueryRequest(int id) : IRequest<Banner>;

    public class BannerQueryHandler : BaseService, IRequestHandler<BannerQueryRequest, Banner>
    {
        public BannerQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<Banner> Handle(BannerQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerRepository.GetById(request.id));
        }
    }
}
