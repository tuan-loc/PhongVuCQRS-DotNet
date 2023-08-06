using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.BannerTypes.Commands
{
    public record UpdateBannerTypeCommandRequest(BannerType bannerType) : IRequest<int>;

    public class UpdateBannerTypeCommandHandler : BaseService, IRequestHandler<UpdateBannerTypeCommandRequest, int>
    {
        public UpdateBannerTypeCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(UpdateBannerTypeCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerTypeRepository.Edit(request.bannerType));
        }
    }
}
