using AutoMapper;
using MediatR;
using PhongVu.Application.Contracts.Persistence;

namespace PhongVu.Application.Features.BannerTypes.Commands
{
    public record DeleteBannerTypeCommandRequest(int id) : IRequest<int>;

    public class DeleteBannerTypeCommandHandler : BaseService, IRequestHandler<DeleteBannerTypeCommandRequest, int>
    {
        public DeleteBannerTypeCommandHandler(ISiteProvider provider, IMapper mapper) : base(provider, mapper)
        {
        }

        public Task<int> Handle(DeleteBannerTypeCommandRequest request, CancellationToken cancellationToken)
        {
            return Task.FromResult(provider.BannerTypeRepository.Delete(request.id));
        }
    }
}
