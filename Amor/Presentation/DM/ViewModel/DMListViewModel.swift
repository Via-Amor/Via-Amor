//
//  DMViewModel.swift
//  Amor
//
//  Created by 김상규 on 10/28/24.
//

import Foundation
import RxSwift
import RxCocoa

final class DMListViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userUseCase: UserUseCase
    private let spaceUseCase: SpaceUseCase
    private let dmUseCase: DMUseCase
    private let chatUseCase: ChatUseCase
    
    init(userUseCase: UserUseCase, spaceUseCase: SpaceUseCase, dmUseCase: DMUseCase, chatUseCase: ChatUseCase) {
        self.userUseCase = userUseCase
        self.spaceUseCase = spaceUseCase
        self.dmUseCase = dmUseCase
        self.chatUseCase = chatUseCase
    }
    
    func transform(_ input: Input) -> Output {
        let getSpaceInfo = PublishSubject<Void>()
        let spaceImage = PublishSubject<String?>()
        let myImage = PublishSubject<String?>()
        let spaceMemberArray = BehaviorRelay<[SpaceMember]>(value: [])
        let getSpaceMembers = PublishSubject<Void>()
        let getDms = PublishSubject<Void>()
        let dmRooms = BehaviorSubject<[DMRoom]>(value: [])
        let getPersistChats = BehaviorSubject<[DMRoom]>(value: [])
        let getServerChats = BehaviorSubject<[DMRoom]>(value: [])
        let persistChats = BehaviorSubject<[Chat?]>(value: [])
        let serverChats = BehaviorSubject<[Chat?]>(value: [])
        let getUnreadCount = BehaviorSubject<[UnreadDMRequst]>(value: [])
        let unreadsInfos = BehaviorSubject<[UnreadInfo?]>(value: [])
        let dmRoomInfoArray = BehaviorSubject<[DMRoomInfo]>(value: [])
        let dmRoomInfoResult = BehaviorRelay<[(DMRoomInfo, Int)]>(value: [])
        let isEmpty = BehaviorRelay<Bool>(value: false)
        let goChatView = PublishRelay<DMRoomInfo>()
        let fetchEnd = PublishRelay<Void>()
        
        input.viewWillAppearTrigger
            .withUnretained(self)
            .flatMap { _ in self.userUseCase.getMyProfile() }
            .bind(with: self) { owner, result in
                switch result {
                case .success(let success):
                    print("spaceID", UserDefaultsStorage.spaceId)
                    getSpaceInfo.onNext(())
                    myImage.onNext(success.profileImage)
                case .failure(let error):
                    print(error)
                }
            }
            .disposed(by: disposeBag)
            
        getSpaceInfo
            .map { SpaceRequestDTO(workspace_id: UserDefaultsStorage.spaceId) }
            .flatMap { self.spaceUseCase.getSpaceInfo(request: $0) }
            .bind(with: self) { owner, result in
                switch result {
                case .success(let success):
                    spaceImage.onNext(success.coverImage)
                    getSpaceMembers.onNext(())
                    getDms.onNext(())
                case .failure(let error):
                    print(error)
                }
            }
            .disposed(by: disposeBag)
        
        getSpaceMembers
            .map { SpaceMembersRequestDTO(workspace_id: UserDefaultsStorage.spaceId) }
            .flatMap{ self.spaceUseCase.getSpaceMembers(request: $0) }
            .bind(with: self) { owner, result in
                switch result {
                case .success(let users):
                    print("내 아이디", UserDefaultsStorage.userId)
                    print("내 스페이스", UserDefaultsStorage.spaceId)
                    let spaceMembers = users.filter({ $0.user_id != UserDefaultsStorage.userId })
                    spaceMemberArray.accept(spaceMembers)
                case .failure(let error):
                    print(error)
                }
            }
            .disposed(by: disposeBag)
        
        getDms
            .map { DMRoomRequestDTO(workspace_id: UserDefaultsStorage.spaceId) }
            .flatMap({ self.dmUseCase.getDMList(request: $0) })
            .bind(with: self) { owner, result in
                switch result {
                case .success(let success):
                    if success.isEmpty {
                        dmRoomInfoResult.accept([])
                    } else {
                        dmRooms.onNext(success)
                        getPersistChats.onNext(success)
                        getServerChats.onNext(success)
                    }
                case .failure(let error):
                    print(error)
                }
            }
            .disposed(by: disposeBag)
        
        getPersistChats
            .flatMap { rooms in
                return Observable.zip(rooms.map({ room in
                    self.chatUseCase.fetchPersistChat(id: room.room_id)
                        .asObservable()
                }))
            }
            .bind(with: self) { owner, persistChatArray in
                var persistLastChats: [Chat?] = []
                persistChatArray.forEach { chats in
                    if !chats.isEmpty {
                        guard let lastChat = chats.last else { return
                            persistLastChats.append(nil)
                        }
                        persistLastChats.append(lastChat)
                    } else {
                        persistLastChats.append(nil)
                    }
                }
                persistChats.onNext(persistLastChats)
            }
            .disposed(by: disposeBag)
        
        Observable.zip(persistChats, getServerChats)
            .map { (persistChats, getServerChats) in
                var request: [ChatRequest] = []
                
                getServerChats.forEach { room in
                    persistChats.forEach { chat in
                        guard let chat = chat else {
                            request.append(ChatRequest(
                                workspaceId: UserDefaultsStorage.spaceId,
                                id: room.room_id,
                                cursor_date: ""
                            ))
                            return
                        }
                        request.append(ChatRequest(
                            workspaceId: UserDefaultsStorage.spaceId,
                            id: room.room_id,
                            cursor_date: chat.createdAt
                        ))
                    }
                }
                
                return request
            }
            .flatMap { requests in
                return Observable.zip(requests.map {
                    self.dmUseCase.getServerDMs(request: $0)
                        .asObservable()
                })
            }
            .bind(with: self) { owner, value in
                var chats: [Chat?] = []
                value.forEach { (result: Result<[ChatResponseDTO], NetworkError>) in
                    switch result {
                    case .success(let value):
                        if let lastChat = value.last {
                            chats.append(lastChat.toDomain())
                        } else {
                            chats.append(nil)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
                print(chats)
                serverChats.onNext(chats)
            }
            .disposed(by: disposeBag)
        
        Observable.zip(dmRooms, persistChats, serverChats)
            .map { dmRooms, persistChats, serverChats -> ([(String?, Chat?, UnreadDMRequst?)]) in
                return dmRooms.map { dmRoom in
                    let lastPersistChats = persistChats.compactMap {
                        $0
                    }.filter {
                        $0.id == dmRoom.room_id
                    }
                    
                    let lastServerChats = serverChats.compactMap {
                        $0
                    }.filter {
                        $0.id == dmRoom.room_id
                    }
                    
                    let lastPersistChat = lastPersistChats.last
                    let lastServerChat = lastServerChats.last
                    
                    let lastChat: Chat? = {
                        switch (lastPersistChat, lastServerChat) {
                        case let (persist?, server?):
                            return persist.createdAt.toServerDate() < server.createdAt.toServerDate() ? server : persist
                        case (_, let server?):
                            return server
                        case (let persist?, _):
                            return persist
                        default:
                            return nil
                        }
                    }()
                    
                    let requestDTO: UnreadDMRequst? = {
                        switch (lastPersistChat, lastServerChat) {
                        case let (persist?, _):
                            let request = UnreadDMRequst(
                                id: dmRoom.room_id,
                                workspaceId: UserDefaultsStorage.spaceId,
                                after: persist.createdAt)
                            print(request)
                            return request
                            
                        case (_, let server?):
                            let request = UnreadDMRequst(
                                id: server.id,
                                workspaceId: UserDefaultsStorage.spaceId,
                                after: dmRoom.createdAt)
                            print(request)
                            
                            return request
                        default:
                            return nil
                        }
                    }()
                    
                    return (dmRoom.user.nickname, lastChat, requestDTO)
                }
            }
            .bind(with: self) { owner, data in
                var dmRoomInfos: [DMRoomInfo] = []
                let requests = data.compactMap({ $0.2 })
                getUnreadCount.onNext(requests)
                
                data.forEach { value in
                    let (roomName, chatting, _) = value
                    guard let chat = chatting, let roomName = roomName else { return }
                    dmRoomInfos.append(DMRoomInfo(
                        room_id: chat.id,
                        roomName: roomName,
                        profileImage: chat.profileImage,
                        content: chat.content,
                        createdAt: chat.createdAt,
                        files: chat.files
                    ))
                }
                dmRoomInfoArray.onNext(dmRoomInfos)
            }
            .disposed(by: disposeBag)
        
        getUnreadCount
            .flatMap { requests in
                return Observable.zip(requests.map { request in
                    self.dmUseCase.getUnreadDMs(request: request)
                        .asObservable()
                })
            }
            .map { results in
                return results.map { result -> UnreadInfo? in
                    switch result {
                    case .success(let success):
                        return UnreadInfo(
                            id: success.room_id,
                            count: success.count
                        )
                    case .failure:
                        return nil
                    }
                }
            }
            .bind(with: self) { owner, requests in
                unreadsInfos.onNext(requests)
            }
            .disposed(by: disposeBag)
        
        Observable.zip(unreadsInfos, dmRoomInfoArray)
            .map{ value in
                let (unreadsInfo, dmRoomInfos) = value
                var results: [(DMRoomInfo, Int)] = []
                
                dmRoomInfos.forEach { roomInfo in
                    unreadsInfo.forEach { unreadInfo in
                        guard let unreadInfo = unreadInfo else {
                            results.append((roomInfo, 0))
                            return
                        }
                        
                        if unreadInfo.id == roomInfo.room_id {
                            results.append((roomInfo, unreadInfo.count))
                        }
                    }
                }
                
                return results
            }
            .bind(with: self) { owner, value in
                dmRoomInfoResult.accept(value)
            }
            .disposed(by: disposeBag)
        
        Observable.zip(spaceMemberArray, dmRoomInfoResult)
            .bind(with: self) { owner, value in
                isEmpty.accept(value.0.isEmpty && value.1.isEmpty)
                fetchEnd.accept(())
            }
            .disposed(by: disposeBag)
        
        input.fromProfileToDM
            .map {
                return (DMRoomRequestDTO(workspace_id: UserDefaultsStorage.spaceId), DMRoomRequestDTOBody(opponent_id: $0))
            }
            .flatMap {
                self.dmUseCase.getDMRoom(request: $0.0, body: $0.1)
            }
            .bind(with: self) { owner, result in
                switch result {
                case .success(let success):
                    let dmRoomInfo = DMRoomInfo(room_id: success.room_id, roomName: success.user.nickname, profileImage: success.user.profileImage, content: nil, createdAt: "", files: [])
                    goChatView.accept(dmRoomInfo)
                case .failure(let failure):
                    print(failure)
                }
            }
            .disposed(by: disposeBag)
        
        return Output(spaceImage: spaceImage, myImage: myImage, spaceMemberArray: spaceMemberArray, dmRoomInfoResult: dmRoomInfoResult, isEmpty: isEmpty, fetchEnd: fetchEnd, goChatView: goChatView)
    }
}

extension DMListViewModel {
    struct Input {
        let viewWillAppearTrigger: Observable<Void>
        let fromProfileToDM: PublishSubject<String>
    }
    
    struct Output {
        let spaceImage: PublishSubject<String?>
        let myImage: PublishSubject<String?>
        let spaceMemberArray: BehaviorRelay<[SpaceMember]>
        let dmRoomInfoResult: BehaviorRelay<[(DMRoomInfo, Int)]>
        let isEmpty: BehaviorRelay<Bool>
        let fetchEnd: PublishRelay<Void>
        let goChatView: PublishRelay<DMRoomInfo>
    }
}
