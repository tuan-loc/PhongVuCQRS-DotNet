using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.Banners.Commands
{
    public record UpdateBannerCommandRequest(Banner banner) : IRequest<int>;

    public class UpdateBannerCommandHandler : BaseService, IRequestHandler<UpdateBannerCommandRequest, int>
    {
        public UpdateBannerCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(UpdateBannerCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerRepository.Edit(request.banner));
        }
    }
}
