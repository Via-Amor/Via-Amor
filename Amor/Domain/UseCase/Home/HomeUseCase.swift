//
//  HomeUseCase.swift
//  Amor
//
//  Created by 김상규 on 11/14/24.
//

import Foundation
import RxSwift

protocol HomeUseCase {
    func login(request: LoginRequestDTO) -> Single<Result<LoginModel, NetworkError>>
    func getSpaceInfo(request: SpaceRequestDTO) -> Single<Result<SpaceInfo, NetworkError>>
    func getMyChannels(request: ChannelRequestDTO) -> Single<Result<[Channel], NetworkError>>
    func getDMRooms(request: DMRoomRequestDTO) -> Single<Result<[DMRoom], NetworkError>>
    func addChannel(path: ChannelRequestDTO, body: AddChannelRequestDTO) -> Single<Result<Channel, NetworkError>>
    func getAllMySpaces() -> Single<Result<[SpaceSimpleInfo], NetworkError>>
}

final class DefaultHomeUseCase: HomeUseCase {
    
    let channelRepository: ChannelRepository
    let spaceRepository: SpaceRepository
    let dmRepository: DMRepository
    
    init(channelRepository: ChannelRepository, spaceRepository: SpaceRepository, dmRepository: DMRepository) {
        self.channelRepository = channelRepository
        self.spaceRepository = spaceRepository
        self.dmRepository = dmRepository
    }
    
    func login(request: LoginRequestDTO) -> Single<Result<LoginModel, NetworkError>> {
        channelRepository.fetchLogin(request: request)
            .flatMap { result in
                switch result {
                case .success(let success):
                    return .just(.success(success.toDomain()))
                case .failure(let error):
                    print("login error", error)
                    return .just(.failure(error))
                }
            }
    }
    
    func getSpaceInfo(request: SpaceRequestDTO) -> Single<Result<SpaceInfo, NetworkError>> {
        spaceRepository.fetchSpaceInfo(request: request)
            .flatMap { result in
                switch result {
                case .success(let success):
                    return .just(.success(success.toDomain()))
                case .failure(let error):
                    print("getSpaceInfo error", error)
                    return .just(.failure(error))
                }
            }
    }
    
    func getMyChannels(request: ChannelRequestDTO) -> Single<Result<[Channel], NetworkError>> {
        channelRepository.fetchChannels(request: request)
            .flatMap { result in
                switch result {
                case .success(let success):
                    return .just(.success(success.map({ $0.toDomain() })))
                case .failure(let error):
                    print("getMyChannels error", error)
                    return .just(.failure(error))
                }
            }
    }
    
    func getDMRooms(request: DMRoomRequestDTO) -> Single<Result<[DMRoom], NetworkError>> {
        dmRepository.fetchDMRooms(request: request)
            .flatMap { result in
                switch result {
                case .success(let success):
                    return .just(.success(success.map({ $0.toDomain() })))
                case .failure(let error):
                    print("getDMRooms error", error)
                    return .just(.failure(error))
                }
            }
    }
    
    func addChannel(path: ChannelRequestDTO, body: AddChannelRequestDTO) -> Single<Result<Channel, NetworkError>> {
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
    
    func getAllMySpaces() -> Single<Result<[SpaceSimpleInfo], NetworkError>> {
        spaceRepository.fetchAllMySpaces()
            .flatMap{ result in
                switch result {
                case .success(let value):
                    return .just(.success(value.map{ $0.toDomain() }))
                case .failure(let error):
                    return .just(.failure(error))
                }
            }
    }
}
