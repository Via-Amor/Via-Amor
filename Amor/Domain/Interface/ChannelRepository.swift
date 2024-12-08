//
//  HomeRepository.swift
//  Amor
//
//  Created by 김상규 on 11/14/24.
//

import Foundation
import RxSwift

protocol ChannelRepository: ChatRepository {
    func fetchChannels(request: ChannelRequestDTO)
    -> Single<Result<[ChannelResponseDTO], NetworkError>>
    func fetchChannelDetail(channelID: String)
    -> Single<Result<ChannelDetailResponseDTO, NetworkError>>
    func addChannel(
        path: ChannelRequestDTO,
        body: AddChannelRequestDTO
    )
    -> Single<Result<ChannelResponseDTO, NetworkError>>
    func editChannel(
        path: ChannelRequestDTO,
        body: EditChannelRequestDTO
    ) -> Single<Result<ChannelResponseDTO, NetworkError>>
    func deleteChannel(
        path: ChannelRequestDTO
    ) -> Single<Result<EmptyResponseDTO, NetworkError>>
}
