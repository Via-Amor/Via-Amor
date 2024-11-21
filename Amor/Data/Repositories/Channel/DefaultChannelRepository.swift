//
//  DefaultHomeRepository.swift
//  Amor
//
//  Created by 김상규 on 11/14/24.
//

import Foundation
import RxSwift

final class DefaultChannelRepository: ChannelRepository {
    
    private let networkManager = NetworkManager.shared
    private let disposeBag = DisposeBag()
    
    func fetchLogin(completionHandler: @escaping (Result<LoginResponseDTO, NetworkError>) -> Void ) {
        let loginDto = LoginRequestDTO(email: "qwe123@gmail.com", password: "Qwer1234!")
        
        networkManager.callNetwork(target: DMTarget.login(body: loginDto), response: LoginResponseDTO.self)
            .subscribe(with: self) { owner, result in
                switch result {
                case .success(let success):
                    completionHandler(.success(success))
                case .failure(let error):
                    print("fetchLogin error", error)
                    completionHandler(.failure(error))
                }
            }
            .disposed(by: disposeBag)
    }
    
    func fetchChannels(spaceID: String, completionHandler: @escaping (Result<[ChannelResponseDTO], NetworkError>) -> Void) {
        let query = ChannelRequestDTO()
        print(query.workspace_id)
        networkManager.callNetwork(target: ChannelTarget.getMyChannels(query: query), response: [ChannelResponseDTO].self)
            .subscribe(with: self) { owner, result in
                switch result {
                case .success(let success):
                    completionHandler(.success(success))
                case .failure(let error):
                    print("fetchChannels error", error)
                    completionHandler(.failure(error))
                }
            }
            .disposed(by: disposeBag)
    }
}
