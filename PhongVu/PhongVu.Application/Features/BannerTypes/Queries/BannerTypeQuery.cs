using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.BannerTypes.Queries
{
    public record BannerTypeQueryRequest(int id) : IRequest<BannerType>;

    public class BannerTypeQueryHandler : BaseService, IRequestHandler<BannerTypeQueryRequest, BannerType>
    {
        public BannerTypeQueryHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<BannerType> Handle(BannerTypeQueryRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerTypeRepository.GetById(request.id));
        }
    }
}
