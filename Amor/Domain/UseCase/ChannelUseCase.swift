//
//  ChannelUseCase.swift
//  Amor
//
//  Created by 홍정민 on 12/1/24.
//

import Foundation
import RxSwift

protocol ChannelUseCase {
    func addChannel(
        path: ChannelRequestDTO,
        body: AddChannelRequestDTO
    ) -> Single<Result<Channel, NetworkError>>
    func fetchChannelDetail(channelID: String)
    -> Single<Result<ChannelDetail, NetworkError>>
    func validateAdmin(ownerID: String)
    -> Observable<Bool>
}

final class DefaultChannelUseCase: ChannelUseCase {
    let channelRepository: ChannelRepository
  
    init(channelRepository: ChannelRepository) {
        self.channelRepository = channelRepository
    }

    func addChannel(path: ChannelRequestDTO, body: AddChannelRequestDTO) 
    -> Single<Result<Channel, NetworkError>> {
        channelRepository.addChannel(path: path, body: body)
            .flatMap{ result in
                switch result {
                case .success(let value):
                    return .just(.success(value.toDomain()))
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
    }
    
    func fetchChannelDetail(channelID: String)
    -> Single<Result<ChannelDetail, NetworkError>> {
        return channelRepository.fetchChannelDetail(channelID: channelID)
            .flatMap { result in
                switch result {
                case .success(let value):
                    return .just(.success(value.toDomain()))
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
    }
    
    func validateAdmin(ownerID: String) 
    -> Observable<Bool> {
        if ownerID == UserDefaultsStorage.userId {
            return .just(true)
        } else {
            return .just(false)
        }
    }
    
}
