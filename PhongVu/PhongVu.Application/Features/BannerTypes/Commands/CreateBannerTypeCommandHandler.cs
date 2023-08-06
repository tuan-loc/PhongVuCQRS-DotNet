using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;
using PhongVu.Domain.Entities;

namespace PhongVu.Application.Features.BannerTypes.Commands
{
    public record CreateBannerTypeCommandRequest(BannerType bannerType) : IRequest<int>;

    public class CreateBannerTypeCommandHandler : BaseService, IRequestHandler<CreateBannerTypeCommandRequest, int>
    {
        public CreateBannerTypeCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(CreateBannerTypeCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerTypeRepository.Add(request.bannerType));
        }

    }
}
